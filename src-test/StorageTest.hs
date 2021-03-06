module StorageTest (tests) where

import Test.Tasty
import Test.Tasty.HUnit
--import Test.Tasty.SmallCheck

import DMSS.Storage.Types
import DMSS.Storage ( getUserKeyKey
                    , storeUserKey
                    , removeUserKey
                    , storeCheckIn
                    , listCheckIns
                    )

import Common

import qualified Database.Persist.Sqlite as P
import Data.List

tests :: [TestTree]
tests =
  [ testCase "store_user_key_test" storeUserKeyTest
  , testCase "store_check_in_test" storeCheckInTest
  , testCase "remove_user_key_test" removeUserKeyTest
  ]

tempDir :: FilePath
tempDir = "storageTest"

storeUserKeyTest :: Assertion
storeUserKeyTest = withTemporaryTestDirectory tempDir ( \_ -> do
    -- Store fake user key
    let fpr = Fingerprint "hello1234"
    _ <- storeUserKey fpr

    -- Check that the fake user key was stored
    k <- getUserKeyKey (Silent True) fpr
    case k of
      Nothing -> assertFailure $ "Could not find UserKey based on (" ++ (unFingerprint fpr) ++ ")"
      _       -> return ()
  )

removeUserKeyTest :: Assertion
removeUserKeyTest = withTemporaryTestDirectory tempDir ( \_ -> do
    -- Store fake user key
    let fpr = Fingerprint "deleteMe1234"
    _ <- storeUserKey fpr

    -- Remove key
    removeUserKey fpr

    -- Check that the fake user key was stored
    k <- getUserKeyKey (Silent True) fpr
    case k of
      Nothing -> return ()
      _       -> assertFailure $ "Found UserKey based on (" ++ (unFingerprint fpr) ++ ") but shouldn't have"
  )

storeCheckInTest :: Assertion
storeCheckInTest = withTemporaryTestDirectory tempDir ( \_ -> do
    -- Store a checkin
    let fpr = Fingerprint "MyFingerprint"
    _ <- storeUserKey fpr
    res <- storeCheckIn fpr (CheckInProof "MyProof")
    case res of
      (Left s) -> assertFailure s
      _ -> return ()
    -- Get a list of checkins
    l <- listCheckIns fpr 10
    -- Verify that only one checkin was returned
    case l of
      (_:[])    -> return ()
      x         -> assertFailure $ "Did not find one checkin: " ++ show x

    -- Create another checkin and verify order is correct
    _ <- storeCheckIn fpr (CheckInProof "More proof")
    _ <- storeCheckIn fpr (CheckInProof "Even more proof")
    l' <- listCheckIns fpr 10
    let createdList = map (\x -> checkInCreated $ P.entityVal x) l'
    if createdList == (reverse . sort) createdList
      then return ()
      else assertFailure "CheckIns were not in decending order"
  )
