WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.RankScore,
        COALESCE(b.Name, 'No Badge') AS UserBadge
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.PostId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1 
    WHERE 
        rp.RankScore <= 3
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.UserBadge,
    pv.UpVotes,
    pv.DownVotes,
    pv.TotalVotes,
    CASE 
        WHEN tp.UserBadge = 'No Badge' THEN 'Not Awarded'
        ELSE 'Awarded'
    END AS BadgeStatus,
    CASE 
        WHEN pv.TotalVotes IS NULL THEN 'No votes yet'
        WHEN pv.TotalVotes = 0 THEN 'No votes'
        ELSE 'Voted'
    END AS VotingStatus,
    CASE 
        WHEN (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId) = 0 THEN 'No Comments'
        ELSE 'Comments Available'
    END AS CommentStatus
FROM 
    TopPosts tp
JOIN 
    PostVotes pv ON tp.PostId = pv.PostId
ORDER BY 
    tp.Score DESC,
    tp.CreationDate ASC
LIMIT 100;