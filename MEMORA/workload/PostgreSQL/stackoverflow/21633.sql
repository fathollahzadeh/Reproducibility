WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostsCount,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
QualifiedUsers AS (
    SELECT 
        Us.UserId,
        Us.DisplayName,
        Us.Reputation,
        Us.PostsCount,
        Us.Upvotes,
        Us.Downvotes,
        CASE 
            WHEN Us.Reputation > 5000 THEN 'Master'
            WHEN Us.Reputation BETWEEN 1000 AND 5000 THEN 'Skilled'
            ELSE 'Novice'
        END AS ExpertiseLevel
    FROM 
        UserScores Us
    WHERE 
        Us.PostsCount > 10
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.AcceptedAnswerId
    FROM 
        Posts P
    WHERE 
        P.ViewCount > (
            SELECT 
                AVG(ViewCount)
            FROM 
                Posts
        )
    ORDER BY 
        P.ViewCount DESC
    LIMIT 5
),
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount,
        MAX(C.CreationDate) AS LastCommentDate
    FROM 
        Comments C
    GROUP BY 
        C.PostId
)
SELECT 
    Pu.UserId,
    Pu.DisplayName,
    Pu.ExpertiseLevel,
    Po.PostId,
    Po.Title,
    Po.ViewCount,
    Po.Score,
    COALESCE(PC.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN Po.AcceptedAnswerId IS NULL THEN 'Not Accepted'
        ELSE 'Accepted'
    END AS AnswerStatus,
    CASE 
        WHEN PC.LastCommentDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 'Inactive Discussion'
        ELSE 'Active Discussion'
    END AS DiscussionStatus
FROM 
    QualifiedUsers Pu
CROSS JOIN 
    PopularPosts Po
LEFT JOIN 
    PostComments PC ON Po.PostId = PC.PostId
WHERE 
    Pu.Reputation IS NOT NULL
    AND Pu.ExpertiseLevel != 'Novice'
ORDER BY 
    Pu.Reputation DESC, Po.ViewCount DESC;