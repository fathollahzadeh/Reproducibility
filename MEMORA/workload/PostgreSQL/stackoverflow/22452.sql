
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(MAX(b.Date), DATE '1900-01-01') AS LastBadgeDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, p.PostTypeId
), FeaturedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CreationDate,
        rp.ScoreRank,
        rp.CommentCount,
        CASE 
            WHEN rp.ScoreRank = 1 THEN 'Featured'
            WHEN rp.Score > 10 THEN 'Popular'
            ELSE 'Regular'
        END AS PopularityStatus,
        CASE 
            WHEN rp.LastBadgeDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 DAYS' THEN 'Active Contributor'
            ELSE 'Inactive Contributor'
        END AS ContributorStatus
    FROM 
        RankedPosts rp
), ExternalLinks AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedLinksCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
), FinalReport AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.ViewCount,
        fp.Score,
        fp.PopularityStatus,
        fp.CommentCount,
        ep.RelatedLinksCount,
        fp.ContributorStatus,
        CASE 
            WHEN fp.PopularityStatus = 'Featured' AND ep.RelatedLinksCount > 0 THEN 'Highly Recommended'
            ELSE 'Standard Recommendation'
        END AS Recommendation
    FROM 
        FeaturedPosts fp
    LEFT JOIN 
        ExternalLinks ep ON fp.PostId = ep.PostId
) 
SELECT 
    fr.PostId,
    fr.Title,
    fr.ViewCount,
    fr.Score,
    fr.PopularityStatus,
    fr.CommentCount,
    fr.RelatedLinksCount,
    fr.ContributorStatus,
    fr.Recommendation
FROM 
    FinalReport fr
WHERE 
    fr.CommentCount > 0 
    AND (fr.PopularityStatus = 'Featured' OR fr.Score > 15)
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC;
