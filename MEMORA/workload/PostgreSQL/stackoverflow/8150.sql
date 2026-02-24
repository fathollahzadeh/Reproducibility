WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        u.DisplayName AS OwnerName, 
        t.TagName AS PrimaryTag, 
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        Tags t ON t.WikiPostId = p.Id
    WHERE 
        u.Reputation > 1000 AND 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
),
RecentTopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp 
    WHERE 
        rp.PostRank = 1
)

SELECT 
    rtp.PostId, 
    rtp.Title, 
    rtp.CreationDate, 
    rtp.Score, 
    rtp.OwnerName, 
    rtp.PrimaryTag, 
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    RecentTopPosts rtp
LEFT JOIN 
    Comments c ON rtp.PostId = c.PostId
LEFT JOIN 
    Votes v ON rtp.PostId = v.PostId
GROUP BY 
    rtp.PostId, rtp.Title, rtp.CreationDate, rtp.Score, rtp.OwnerName, rtp.PrimaryTag
ORDER BY 
    rtp.Score DESC, 
    rtp.CreationDate DESC
LIMIT 10;