
WITH RECURSIVE RecentPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),

UserDetails AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

PostLinksDetails AS (
    SELECT
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastModified
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),

FinalResults AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        ud.DisplayName AS OwnerName,
        ud.Reputation,
        rp.ViewCount,
        COALESCE(pl.RelatedPostCount, 0) AS RelatedPostCount,
        COALESCE(phd.HistoryCount, 0) AS EditHistoryCount,
        phd.LastModified,
        CASE 
            WHEN ud.UpvoteCount > ud.DownvoteCount THEN 'Positive'
            ELSE 'Negative'
        END AS UserVoteStatus
    FROM 
        RecentPosts rp
    JOIN 
        UserDetails ud ON rp.OwnerUserId = ud.UserId
    LEFT JOIN 
        PostLinksDetails pl ON rp.Id = pl.PostId
    LEFT JOIN 
        PostHistoryDetails phd ON rp.Id = phd.PostId
    WHERE 
        rp.rn = 1
)

SELECT 
    FR.PostId,
    FR.Title,
    FR.OwnerName,
    FR.Reputation,
    FR.ViewCount,
    FR.RelatedPostCount,
    FR.EditHistoryCount,
    FR.LastModified,
    FR.UserVoteStatus
FROM 
    FinalResults FR
ORDER BY 
    FR.Reputation DESC, 
    FR.ViewCount DESC;
