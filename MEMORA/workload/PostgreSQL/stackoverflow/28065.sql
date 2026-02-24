
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        p.CreationDate,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title, 
        Tags,
        OwnerDisplayName,
        CommentCount,
        AnswerCount,
        CreationDate,
        RankByUser
    FROM 
        RankedPosts
    WHERE 
        RankByUser <= 5 
),
ActiveUser AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN ph.PostId IS NOT NULL THEN 1 ELSE 0 END) AS HistoryCount,
        MAX(u.LastAccessDate) AS LastActive
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(DISTINCT p.Id) > 10 
),
UserPostBenchmark AS (
    SELECT 
        f.PostId,
        f.Title,
        f.Tags,
        f.OwnerDisplayName,
        a.DisplayName AS ActiveUserDisplayName,
        a.Reputation AS ActiveUserReputation,
        f.CommentCount,
        f.AnswerCount,
        f.CreationDate,
        a.PostsCount,
        a.HistoryCount,
        a.LastActive
    FROM 
        FilteredPosts f
    JOIN 
        ActiveUser a ON f.OwnerDisplayName = a.DisplayName
    ORDER BY 
        f.CreationDate DESC
)
SELECT 
    *,
    CONCAT('Post "', Title, '" by ', OwnerDisplayName, ' has ', CommentCount, ' comments and ', AnswerCount, ' answers. Active user: ', ActiveUserDisplayName, ' (Reputation: ', ActiveUserReputation, ')') AS BenchmarkSummary
FROM 
    UserPostBenchmark
LIMIT 100;
