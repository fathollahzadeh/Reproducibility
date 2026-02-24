
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 10
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
FinalReport AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        tp.CommentCount,
        pv.UpVotes,
        pv.DownVotes,
        COALESCE(pb.BadgeCount, 0) AS BadgeCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostVotes pv ON tp.PostId = pv.PostId
    LEFT JOIN 
        PostBadges pb ON tp.PostId = pb.UserId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Score,
    fr.ViewCount,
    fr.CommentCount,
    fr.UpVotes,
    fr.DownVotes,
    fr.BadgeCount,
    CASE 
        WHEN fr.Score IS NULL THEN 'No Score'
        WHEN fr.Score > 10 THEN 'High Score'
        ELSE 'Moderate Score'
    END AS ScoreCategory
FROM 
    FinalReport fr
WHERE 
    fr.BadgeCount > 0
ORDER BY 
    fr.Score DESC, fr.Title ASC;
