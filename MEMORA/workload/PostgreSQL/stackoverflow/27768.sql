
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        COALESCE(A.AnswerCount, 0) AS AnswerCount,
        COALESCE(V.VoteCount, 0) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId
    ) A ON p.Id = A.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) V ON p.Id = V.PostId
    WHERE 
        p.PostTypeId = 1 
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(A.AnswerCount, 0)) AS TotalAnswers,
        COALESCE(SUM(V.VoteCount), 0) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN Posts p ON U.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId
    ) A ON p.Id = A.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) V ON p.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)
SELECT 
    R.PostId,
    R.Title,
    R.CreationDate,
    R.Body,
    R.AnswerCount,
    R.VoteCount,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    U.TotalPosts,
    U.TotalAnswers,
    U.TotalVotes
FROM 
    RankedPosts R
JOIN 
    UserStats U ON R.OwnerUserId = U.UserId
WHERE 
    R.UserPostRank <= 5 
ORDER BY 
    U.TotalVotes DESC, R.CreationDate DESC;
