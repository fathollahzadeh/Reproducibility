WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
),
TopPosts AS (
    SELECT 
        rp.*, 
        CASE 
            WHEN rp.UpVoteCount > rp.DownVoteCount THEN 'Positive'
            WHEN rp.UpVoteCount < rp.DownVoteCount THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5  
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.ViewCount,
        tp.Score,
        tp.VoteSentiment,
        COALESCE(LINKS.LinkCount, 0) AS RelatedLinks
    FROM 
        TopPosts tp
    LEFT JOIN (
        SELECT 
            pl.PostId, 
            COUNT(pl.RelatedPostId) AS LinkCount
        FROM 
            PostLinks pl
        GROUP BY 
            pl.PostId
    ) AS LINKS ON LINKS.PostId = tp.PostId
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount, 
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostContributions AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
        ub.BadgeNames
    FROM 
        Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN UserBadges ub ON ub.UserId = p.OwnerUserId
    GROUP BY 
        p.Id, ub.BadgeCount, ub.BadgeNames
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.VoteSentiment,
    pc.CommentCount,
    pc.UserBadgeCount,
    pc.BadgeNames
FROM 
    PostDetails pd
JOIN 
    PostContributions pc ON pc.PostId = pd.PostId
ORDER BY 
    pd.Score DESC, pd.CreationDate DESC;