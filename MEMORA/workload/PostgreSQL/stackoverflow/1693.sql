
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
        AND p.Score > 0
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.Reputation
), 
PostStatistics AS (
    SELECT 
        rp.Title,
        ur.UserId,
        ur.Reputation,
        ur.UpVotes,
        ur.DownVotes,
        rp.Score,
        rp.AnswerCount,
        COUNT(c.Id) AS CommentCount,
        MAX(ph.CreationDate) AS LastEditedDate
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        Comments c ON rp.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON rp.Id = ph.PostId
    WHERE 
        rp.UserPostRank <= 3
    GROUP BY 
        rp.Title, ur.UserId, ur.Reputation, ur.UpVotes, ur.DownVotes, rp.Score, rp.AnswerCount
)
SELECT 
    ps.Title,
    ps.Reputation,
    ps.UpVotes - ps.DownVotes AS NetVotes,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount,
    COALESCE(NULLIF(ps.LastEditedDate, rp.CreationDate), rp.CreationDate) AS RecentActivity
FROM 
    PostStatistics ps
JOIN 
    RankedPosts rp ON ps.Title = rp.Title
WHERE 
    (ps.UpVotes - ps.DownVotes) > 10
ORDER BY 
    ps.Score DESC
LIMIT 100 OFFSET 0;
