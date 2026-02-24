
WITH RECURSIVE UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UserScore AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        (SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END)) AS Score
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(p.PostCount, 0) AS TotalPosts,
        COALESCE(s.Upvotes, 0) AS TotalUpvotes,
        COALESCE(s.Downvotes, 0) AS TotalDownvotes,
        COALESCE(s.Score, 0) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        UserPostCounts p ON u.Id = p.UserId
    LEFT JOIN 
        UserScore s ON u.Id = s.UserId
    WHERE 
        u.Reputation > 1000
    ORDER BY 
        TotalScore DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COALESCE(AVG(p.Score), 0) AS AverageScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
CombinedStatistics AS (
    SELECT 
        u.DisplayName,
        p.Title,
        p.ViewCount,
        p.CommentCount,
        p.UpvoteCount,
        p.DownvoteCount,
        u.TotalPosts,
        p.AverageScore
    FROM 
        TopUsers u
    JOIN 
        PostStatistics p ON u.Id = p.PostId
)
SELECT 
    cs.DisplayName,
    cs.Title,
    cs.ViewCount,
    cs.CommentCount,
    cs.UpvoteCount,
    cs.DownvoteCount,
    cs.TotalPosts,
    CASE 
        WHEN cs.AverageScore IS NULL THEN 'No Score'
        ELSE CAST(cs.AverageScore AS VARCHAR)
    END AS AverageScore
FROM 
    CombinedStatistics cs
ORDER BY 
    cs.UpvoteCount DESC, cs.ViewCount DESC;
