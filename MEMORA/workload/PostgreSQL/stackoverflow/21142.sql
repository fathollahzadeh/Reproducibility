
WITH RankedBadges AS (
    SELECT 
        UserId,
        Name,
        Date,
        ROW_NUMBER() OVER (PARTITION BY UserId ORDER BY Date DESC) AS BadgeRank
    FROM Badges
), 
UserReputationStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyAmount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
UserHistory AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS TotalHistoryEntries,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS HistoryTypes,
        MAX(PH.CreationDate) AS LastHistoryEntryDate
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY PH.UserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalBountyAmount,
    U.TotalUpVotes,
    U.TotalDownVotes,
    CASE 
        WHEN U.TotalPosts = 0 THEN 'No Posts'
        WHEN U.TotalComments = 0 THEN 'No Comments'
        ELSE 'Active Contributor'
    END AS ContributionStatus,
    COALESCE(RB.Name, 'No Badges') AS LatestBadge,
    UH.TotalHistoryEntries,
    UH.HistoryTypes,
    UH.LastHistoryEntryDate
FROM UserReputationStats U
LEFT JOIN RankedBadges RB ON U.UserId = RB.UserId AND RB.BadgeRank = 1
LEFT JOIN UserHistory UH ON U.UserId = UH.UserId
WHERE U.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY U.TotalUpVotes DESC, U.TotalPosts DESC;
