
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, pt.Name
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ScoreRank,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.ScoreRank = 1 THEN 'Top Post'
            WHEN rp.ScoreRank <= 5 THEN 'Popular'
            ELSE 'Regular'
        END AS PostCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 0
),
LatestActivity AS (
    SELECT 
        p.Id,
        MAX(p.LastActivityDate) AS LastActivity
    FROM 
        Posts p
    WHERE 
        p.LastActivityDate IS NOT NULL
    GROUP BY 
        p.Id
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.CreationDate,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.PostCategory,
    la.LastActivity,
    CASE 
        WHEN la.LastActivity < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' THEN 'Inactive'
        ELSE 'Active'
    END AS ActivityStatus
FROM 
    FilteredPosts fp
LEFT JOIN 
    LatestActivity la ON fp.PostId = la.Id
WHERE 
    fp.Score IS NOT NULL
ORDER BY 
    fp.Score DESC, fp.CreationDate ASC;
