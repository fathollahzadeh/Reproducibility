
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '3 MONTH'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        ur.DisplayName,
        ur.Reputation,
        ur.TotalBadges
    FROM 
        RecentPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.rn = 1
),
TopPosts AS (
    SELECT 
        ps.*,
        DENSE_RANK() OVER (ORDER BY ps.Score DESC) AS ScoreRank
    FROM 
        PostStatistics ps
    WHERE 
        ps.Reputation > 1000 
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.DisplayName,
    tp.Reputation,
    tp.TotalBadges,
    COALESCE(c.CommentCount, 0) AS TotalComments,
    COALESCE(v.UpVotes, 0) AS TotalUpVotes,
    COALESCE(v.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN tp.ScoreRank <= 10 THEN 'Top 10'
        WHEN tp.ScoreRank <= 50 THEN 'Top 50'
        ELSE 'Other'
    END AS RankCategory
FROM 
    TopPosts tp
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
) c ON tp.PostId = c.PostId
LEFT JOIN (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
) v ON tp.PostId = v.PostId
WHERE 
    tp.Reputation IS NOT NULL AND 
    tp.ViewCount IS NOT NULL 
ORDER BY 
    RankCategory, tp.Score DESC;
