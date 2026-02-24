
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COALESCE(COUNT(DISTINCT v.Id), 0) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 DAY'
    GROUP BY 
        p.Id, p.Title, p.Score
), TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CommentCount,
        rp.VoteCount,
        rp.Rank
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
), UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT bp.PostId) AS PostsEngaged,
        SUM(bp.CommentCount) AS TotalComments,
        SUM(bp.VoteCount) AS TotalVotes
    FROM 
        Users u
    JOIN 
        TopPosts bp ON u.Id = bp.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.Reputation,
    ue.PostsEngaged,
    ue.TotalComments,
    ue.TotalVotes
FROM 
    UserEngagement ue
ORDER BY 
    ue.Reputation DESC, 
    ue.PostsEngaged DESC
LIMIT 10;
