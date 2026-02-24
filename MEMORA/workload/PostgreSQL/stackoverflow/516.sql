WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY COALESCE(MAX(ph.CreationDate), p.CreationDate) DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11, 12, 13)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
PopularPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        (rp.UpVotes - rp.DownVotes) AS Score,
        CASE 
            WHEN rp.CommentCount > 10 THEN 'High Activity'
            WHEN rp.CommentCount BETWEEN 5 AND 10 THEN 'Moderate Activity'
            ELSE 'Low Activity'
        END AS ActivityLevel
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 AND rp.CommentCount > 0
),
TopPosts AS (
    SELECT 
        pp.*,
        DENSE_RANK() OVER (ORDER BY pp.Score DESC) AS PostRank
    FROM 
        PopularPosts pp
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.Score,
    tp.ActivityLevel
FROM 
    TopPosts tp
WHERE 
    tp.PostRank <= 10 OR 
    (tp.ActivityLevel = 'High Activity' AND tp.CommentCount > 0)
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
