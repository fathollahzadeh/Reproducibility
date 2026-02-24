
WITH UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        (u.UpVotes - u.DownVotes) AS NetVotes
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score AS PostScore,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserWithTopPosts AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        tp.PostId,
        tp.Title,
        tp.PostScore,
        tp.ViewCount,
        tp.AnswerCount,
        tp.CreationDate
    FROM 
        UserScores us
    JOIN 
        TopPosts tp ON us.UserId = tp.OwnerUserId
    WHERE 
        tp.PostRank <= 3
)
SELECT 
    tp.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(COALESCE(b.Class, 0)) AS TotalBadges,
    AVG(tp.PostScore) AS AveragePostScore,
    SUM(tp.ViewCount) AS TotalViews,
    STRING_AGG(DISTINCT tp.Title, '; ') AS TopPostTitles
FROM 
    UserWithTopPosts tp
LEFT JOIN 
    Posts p ON tp.PostId = p.Id
LEFT JOIN 
    Badges b ON tp.UserId = b.UserId
GROUP BY 
    tp.DisplayName
ORDER BY 
    TotalPosts DESC, AveragePostScore DESC
LIMIT 10;
