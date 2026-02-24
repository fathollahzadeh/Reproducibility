WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(c.Count, 0) AS CommentCount,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS Count 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
),
HighScoringPosts AS (
    SELECT 
        rp.*, 
        CASE 
            WHEN rp.Score >= 100 THEN 'High'
            WHEN rp.Score >= 50 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
)
SELECT 
    p.PostId,
    p.Title,
    p.Score,
    p.ScoreCategory,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    u.BadgeCount,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes
FROM 
    HighScoringPosts p
JOIN 
    UserReputation u ON p.PostId IN (
        SELECT 
            ParentId 
        FROM 
            Posts 
        WHERE 
            OwnerUserId = u.UserId
    )
ORDER BY 
    p.Score DESC, u.Reputation DESC;
