WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score > 0
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        v.PostId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostLinksSummary AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostsCount,
        SUM(CASE WHEN lt.Name = 'Duplicate' THEN 1 ELSE 0 END) AS DuplicateCount
    FROM 
        PostLinks pl
    INNER JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
    GROUP BY 
        pl.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    COALESCE(rp.Score, 0) AS Score,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    COALESCE(rv.VoteCount, 0) AS TotalVotes,
    COALESCE(rv.UpVotes, 0) - COALESCE(rv.DownVotes, 0) AS NetVotes,
    COALESCE(pls.RelatedPostsCount, 0) AS TotalRelatedPosts,
    rp.Tags,
    rp.CreationDate,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Badges b 
            WHERE b.UserId = rp.OwnerUserId AND b.Class = 1
        ) THEN 'Gold Badge Holder'
        WHEN EXISTS (
            SELECT 1 
            FROM Badges b 
            WHERE b.UserId = rp.OwnerUserId AND b.Class = 2
        ) THEN 'Silver Badge Holder'
        ELSE 'No Badge'
    END AS BadgeStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    PostLinksSummary pls ON rp.PostId = pls.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, 
    rp.Title ASC
LIMIT 100;