
WITH RecursiveBadges AS (
    SELECT 
        B.UserId, 
        B.Name AS BadgeName, 
        B.Class,
        ROW_NUMBER() OVER (PARTITION BY B.UserId ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Badges B
),
UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COALESCE(MAX(C.CreationDate), '1900-01-01') AS MostRecentCommentDate
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
FilteredPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.Body,
        P.CreationDate,
        P.AcceptedAnswerId,
        P.OwnerUserId,
        COALESCE(UPV.UpVotes, 0) - COALESCE(DNV.DownVotes, 0) AS NetVotes
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) UPV ON P.Id = UPV.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS DownVotes
        FROM 
            Votes
        WHERE 
            VoteTypeId = 3
        GROUP BY 
            PostId
    ) DNV ON P.Id = DNV.PostId
    WHERE 
        P.ViewCount >= (SELECT AVG(ViewCount) FROM Posts)
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    RB.BadgeName,
    RB.Class,
    FP.PostId,
    FP.Title,
    FP.NetVotes,
    U.MostRecentCommentDate,
    CASE 
        WHEN RB.Class = 1 THEN 'Gold'
        WHEN RB.Class = 2 THEN 'Silver'
        WHEN RB.Class = 3 THEN 'Bronze'
        ELSE 'No Badge'
    END AS BadgeType
FROM 
    UserStats U
LEFT JOIN 
    RecursiveBadges RB ON U.UserId = RB.UserId AND RB.BadgeRank = 1
LEFT JOIN 
    FilteredPosts FP ON U.UserId = FP.OwnerUserId
WHERE 
    U.Reputation > 1000 
    AND (U.TotalBounty > 0 OR U.MostRecentCommentDate > '2020-01-01')
    AND (FP.NetVotes IS NULL OR FP.NetVotes > 10 OR (FP.NetVotes IS NOT NULL AND FP.NetVotes < -5))
ORDER BY 
    U.Reputation DESC, 
    FP.NetVotes DESC,
    FP.CreationDate DESC
LIMIT 100;
