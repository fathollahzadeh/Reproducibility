
WITH RECURSIVE UserPostCount AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(P.Id) AS PostCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM UserPostCount
    WHERE PostCount > 0
),
PostVoteDetails AS (
    SELECT 
        P.Id AS PostId, 
        COUNT(V.Id) AS VoteCount, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id
),
UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeLevel
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
FinalResults AS (
    SELECT 
        U.UserId, 
        U.DisplayName, 
        U.PostCount, 
        PV.VoteCount, 
        PV.UpVotes, 
        PV.DownVotes, 
        UB.BadgeCount, 
        UB.HighestBadgeLevel
    FROM TopUsers U
    LEFT JOIN PostVoteDetails PV ON U.UserId = PV.PostId 
    LEFT JOIN UserBadges UB ON U.UserId = UB.UserId
)
SELECT 
    FR.UserId,
    FR.DisplayName,
    COALESCE(FR.PostCount, 0) AS TotalPosts,
    COALESCE(FR.VoteCount, 0) AS TotalVotes,
    COALESCE(FR.UpVotes, 0) AS TotalUpVotes,
    COALESCE(FR.DownVotes, 0) AS TotalDownVotes,
    COALESCE(FR.BadgeCount, 0) AS TotalBadges,
    COALESCE(FR.HighestBadgeLevel, 0) AS HighestBadgeLevel,
    CASE 
        WHEN FR.HighestBadgeLevel = 1 THEN 'Gold'
        WHEN FR.HighestBadgeLevel = 2 THEN 'Silver'
        WHEN FR.HighestBadgeLevel = 3 THEN 'Bronze'
        ELSE 'No Badge'
    END AS BadgeLevelDescription
FROM FinalResults FR
ORDER BY TotalPosts DESC, TotalVotes DESC
LIMIT 10;
