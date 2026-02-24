
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByDate,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.ViewCount IS NOT NULL
),
QuestionBadges AS (
    SELECT 
        b.UserId,
        MAX(b.Class) AS HighestBadgeClass,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    JOIN 
        Posts p ON b.UserId = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        b.UserId
),
CommentsWithVoteCounts AS (
    SELECT 
        c.Id AS CommentId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        c.PostId,
        c.Text,
        c.CreationDate
    FROM 
        Comments c
    LEFT JOIN 
        Votes v ON c.PostId = v.PostId
    GROUP BY 
        c.Id, c.PostId, c.Text, c.CreationDate
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        qb.BadgeCount,
        COALESCE(cw.UpVoteCount, 0) AS TotalUpVotes,
        COALESCE(cw.DownVoteCount, 0) AS TotalDownVotes,
        CASE 
            WHEN rp.RankByViews = 1 THEN 'Top Viewed Post'
            WHEN rp.RankByViews <= 5 THEN 'Top 5 Viewed Posts'
            ELSE 'Other Posts'
        END AS ViewRanking,
        CASE 
            WHEN qb.HighestBadgeClass = 1 THEN 'Gold'
            WHEN qb.HighestBadgeClass = 2 THEN 'Silver'
            ELSE 'Bronze or No Badge'
        END AS BadgeLevel
    FROM 
        RankedPosts rp
    LEFT JOIN 
        QuestionBadges qb ON rp.OwnerUserId = qb.UserId
    LEFT JOIN 
        CommentsWithVoteCounts cw ON rp.PostId = cw.PostId
    WHERE 
        rp.RankByViews <= 5 OR rp.RankByDate <= 5
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.ViewCount,
    fr.BadgeCount,
    fr.TotalUpVotes,
    fr.TotalDownVotes,
    fr.ViewRanking,
    fr.BadgeLevel,
    CASE 
        WHEN fr.TotalUpVotes = 0 AND fr.TotalDownVotes = 0 THEN 'No Votes'
        ELSE 'Votes Registered'
    END AS VoteStatus
FROM 
    FinalResults fr
WHERE 
    fr.BadgeCount > 0 OR fr.TotalUpVotes > 0 OR fr.TotalDownVotes > 0
ORDER BY 
    fr.ViewCount DESC, fr.TotalUpVotes DESC
LIMIT 50;
