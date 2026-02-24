WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Ranking
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
AcceptedAnswers AS (
    SELECT 
        p.Id AS AnswerId,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        p.Score AS AnswerScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        (SUM(coalesce(v.VoteTypeId::int, 0)) FILTER (WHERE v.VoteTypeId = 2) - 
        SUM(coalesce(v.VoteTypeId::int, 0)) FILTER (WHERE v.VoteTypeId = 3)) AS NetVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalComments,
    U.NetVotes,
    R.PostId,
    R.Title,
    R.Ranking,
    COALESCE(A.AnswerId, -1) AS BestAcceptedAnswerId,
    COALESCE(A.AnswerScore, 0) AS BestAcceptedAnswerScore,
    CASE 
        WHEN U.NetVotes > 10 THEN 'Active Contributor' 
        WHEN U.TotalPosts > 20 THEN 'Frequent Poster' 
        ELSE 'New User' 
    END AS UserCategory,
    CASE 
        WHEN U.TotalPosts IS NOT NULL AND U.TotalPosts % 2 = 0 THEN 'Even Posts' 
        ELSE 'Odd Posts' 
    END AS PostsParity
FROM 
    UserActivity U
LEFT JOIN 
    RankedPosts R ON U.UserId = (SELECT OwnerUserId FROM Posts p WHERE p.Id = R.PostId LIMIT 1)
LEFT JOIN 
    AcceptedAnswers A ON R.AcceptedAnswerId = A.AnswerId
WHERE 
    U.TotalPosts IS NOT NULL 
    AND U.TotalComments IS NOT NULL 
    AND NOT EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerUserId = U.UserId 
        AND p.ClosedDate IS NOT NULL
    )
ORDER BY 
    U.NetVotes DESC, 
    R.ViewCount ASC NULLS LAST;