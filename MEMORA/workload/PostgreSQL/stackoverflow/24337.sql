
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        AVG(P.Score) OVER (PARTITION BY U.Id) AS AvgPostScore,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation IS NOT NULL
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
RecentActivity AS (
    SELECT 
        U.Id AS UserId,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        MAX(C.CreationDate) AS LastCommentDate,
        MAX(V.CreationDate) AS LastVoteDate
    FROM 
        Users U
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        COALESCE(SUM(V.BountyAmount) FILTER (WHERE V.VoteTypeId = 8), 0) AS TotalBounty,
        COUNT(C.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = P.Id) AS TotalVotes,
        P.CreationDate,
        P.ViewCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.Score, P.CreationDate, P.ViewCount
),
AggregatedStats AS (
    SELECT 
        U.UserId,
        U.Reputation,
        U.AvgPostScore,
        UB.BadgeCount,
        UB.BadgeNames,
        RA.CommentCount AS UserCommentCount,
        RA.VoteCount AS UserVoteCount,
        PA.TotalVotes AS PostVoteCount,
        PA.TotalBounty,
        PA.CommentCount AS PostCommentCount,
        PA.ViewCount AS PostViewCount
    FROM 
        UserReputation U
    LEFT JOIN 
        UserBadges UB ON U.UserId = UB.UserId
    LEFT JOIN 
        RecentActivity RA ON U.UserId = RA.UserId
    LEFT JOIN 
        PostStats PA ON PA.PostId = (
            SELECT P.Id FROM Posts P 
            WHERE P.OwnerUserId = U.UserId 
            ORDER BY P.CreationDate DESC LIMIT 1
        )
    WHERE 
        U.ReputationRank <= 10  
)
SELECT 
    A.UserId,
    A.Reputation,
    A.AvgPostScore,
    A.BadgeCount,
    A.BadgeNames,
    COALESCE(A.UserCommentCount, 0) AS UserCommentCount,
    COALESCE(A.UserVoteCount, 0) AS UserVoteCount,
    COALESCE(A.PostVoteCount, 0) AS PostVoteCount,
    COALESCE(A.TotalBounty, 0) AS TotalBounty,
    COALESCE(A.PostCommentCount, 0) AS PostCommentCount,
    COALESCE(A.PostViewCount, 0) AS PostViewCount,
    CASE 
        WHEN A.Reputation < 100 THEN 'Beginner'
        WHEN A.Reputation < 500 THEN 'Intermediate'
        ELSE 'Expert'
    END AS UserLevel,
    CASE 
        WHEN A.BadgeCount > 5 THEN 'Highly Recognized'
        ELSE 'General User'
    END AS BadgeStatus
FROM 
    AggregatedStats A
ORDER BY 
    A.Reputation DESC, A.UserId;
