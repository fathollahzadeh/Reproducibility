WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
HotQuestions AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        OwnerDisplayName, 
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank = 1 AND CommentCount > 5 AND Score > 10
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT h.PostId) AS PostsEdited
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        PostHistory h ON h.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    hq.Title,
    hq.CreationDate,
    hq.Score,
    hq.ViewCount,
    hq.OwnerDisplayName,
    ue.DisplayName AS EngagingUser,
    ue.UpVotes,
    ue.DownVotes,
    ue.PostsEdited
FROM 
    HotQuestions hq
JOIN 
    UserEngagement ue ON ue.UpVotes > 0 OR ue.DownVotes > 0
ORDER BY 
    hq.Score DESC, hq.ViewCount DESC
LIMIT 10;