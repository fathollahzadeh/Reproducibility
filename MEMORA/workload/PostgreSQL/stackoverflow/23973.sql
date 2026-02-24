
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.ViewCount,
        COALESCE(u.Reputation, 0) AS UserReputation,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEdited,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPosts
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Score, p.ViewCount, u.Reputation
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Score,
        ps.ViewCount,
        ps.UserReputation,
        ps.CommentCount,
        ps.HistoryCount,
        ps.LastEdited,
        ps.RelatedPosts,
        RANK() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC NULLS LAST) AS ScoreRank,
        RANK() OVER (ORDER BY ps.UserReputation DESC, ps.CommentCount DESC NULLS LAST) AS ReputationRank
    FROM 
        PostStats ps
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Score,
        rp.ViewCount,
        rp.UserReputation,
        rp.CommentCount,
        rp.HistoryCount,
        rp.LastEdited,
        rp.RelatedPosts,
        CASE 
            WHEN rp.Score >= 100 THEN 'Hot'
            WHEN rp.Score >= 50 THEN 'Warm'
            ELSE 'Cool'
        END AS Temperature
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 10 OR rp.ReputationRank <= 10
),
UserBadges AS (
    SELECT
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalResults AS (
    SELECT 
        tp.PostId,
        tp.Score,
        tp.ViewCount,
        tp.UserReputation,
        tp.CommentCount,
        tp.HistoryCount,
        tp.LastEdited,
        tp.RelatedPosts,
        tp.Temperature,
        ub.BadgeNames
    FROM 
        TopPosts tp
    LEFT JOIN 
        UserBadges ub ON tp.UserReputation = ub.UserId
)
SELECT
    fr.PostId,
    fr.Score,
    fr.ViewCount,
    COALESCE(fr.BadgeNames, 'No Badges') AS BadgeNames,
    fr.Temperature,
    CASE 
        WHEN fr.CommentCount > 5 THEN 'Highly Engaged'
        ELSE 'Less Engaged'
    END AS EngagementLevel,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = fr.PostId AND v.VoteTypeId = 3) THEN 'Has Downvotes'
        ELSE 'No Downvotes'
    END AS DownvoteStatus,
    (SELECT COUNT(*) FROM Posts p2 WHERE p2.OwnerUserId = (SELECT OwnerUserId FROM Posts WHERE Id = fr.PostId)) AS SameUserPosts
FROM 
    FinalResults fr
WHERE 
    fr.UserReputation IS NOT NULL
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC;
