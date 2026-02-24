WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation, 
        U.CreationDate, 
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties, 
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId 
    LEFT JOIN 
        Badges B ON U.Id = B.UserId 
    GROUP BY 
        U.Id, U.Reputation, U.CreationDate
), 

PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),

TopEngagedPosts AS (
    SELECT 
        PE.PostId, 
        PE.CommentCount, 
        PE.UpVotes, 
        PE.DownVotes, 
        PE.AvgViewCount,
        RANK() OVER (ORDER BY PE.CommentCount DESC, PE.UpVotes DESC) AS EngagementRank
    FROM 
        PostEngagement PE
    WHERE 
        PE.CommentCount > 0
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    S.TotalBounties,
    S.BadgeCount,
    P.Title,
    P.CreationDate,
    E.CommentCount,
    E.UpVotes,
    E.DownVotes,
    E.AvgViewCount,
    COALESCE(CAST(E.AvgViewCount * 1.0 / NULLIF(E.CommentCount, 0) AS DECIMAL(10, 2)), 0) AS ViewPerComment
FROM 
    Users U
LEFT JOIN 
    UserStatistics S ON U.Id = S.UserId
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    TopEngagedPosts E ON P.Id = E.PostId
WHERE 
    (U.Reputation > 500 OR S.BadgeCount > 5) 
    AND (E.UpVotes > 0 OR E.CommentCount IS NULL)
    AND P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
ORDER BY 
    S.TotalBounties DESC, U.Reputation DESC, E.CommentCount DESC;