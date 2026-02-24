
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        p.Tags
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
        AND p.ViewCount IS NOT NULL
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

PostVoteCounts AS (
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

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        ub.BadgeCount,
        pvc.UpVotes,
        pvc.DownVotes,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.PostId IN (
            SELECT 
                p.Id 
            FROM 
                Posts p 
            WHERE 
                p.OwnerUserId IS NOT NULL
        )
    LEFT JOIN 
        PostVoteCounts pvc ON rp.PostId = pvc.PostId
    LEFT JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(rp.Tags, '<>')) AS TagName
        ) AS t ON TRUE
    WHERE 
        rp.Rank <= 10
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.ViewCount, ub.BadgeCount, pvc.UpVotes, pvc.DownVotes
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.BadgeCount,
    COALESCE(tp.UpVotes, 0) AS UpVotes,
    COALESCE(tp.DownVotes, 0) AS DownVotes,
    tp.TagsList,
    CASE 
        WHEN tp.Score < 0 THEN 'Needs Improvement'
        WHEN tp.Score >= 0 AND tp.Score < 10 THEN 'Decent'
        ELSE 'Outstanding'
    END AS PostQuality
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC
LIMIT 5 OFFSET 0;
