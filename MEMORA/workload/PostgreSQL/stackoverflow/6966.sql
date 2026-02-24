
WITH RecentQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
), 
QuestionStats AS (
    SELECT 
        rq.QuestionId,
        rq.Title,
        rq.CreationDate,
        rq.ViewCount,
        rq.Score,
        rq.OwnerDisplayName,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        RecentQuestions rq
    LEFT JOIN 
        Comments c ON rq.QuestionId = c.PostId
    LEFT JOIN 
        Votes v ON rq.QuestionId = v.PostId
    LEFT JOIN 
        Badges b ON rq.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
    GROUP BY 
        rq.QuestionId, rq.Title, rq.CreationDate, rq.ViewCount, rq.Score, rq.OwnerDisplayName
), 
OverallStats AS (
    SELECT 
        COUNT(*) AS TotalQuestions,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore,
        SUM(CommentCount) AS TotalComments,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes,
        SUM(GoldBadges) AS TotalGoldBadges,
        SUM(SilverBadges) AS TotalSilverBadges,
        SUM(BronzeBadges) AS TotalBronzeBadges
    FROM 
        QuestionStats
)
SELECT 
    qs.*,
    os.TotalQuestions,
    os.TotalViews,
    os.TotalScore,
    os.TotalComments,
    os.TotalUpVotes,
    os.TotalDownVotes,
    os.TotalGoldBadges,
    os.TotalSilverBadges,
    os.TotalBronzeBadges
FROM 
    QuestionStats qs
CROSS JOIN 
    OverallStats os
ORDER BY 
    qs.CreationDate DESC
LIMIT 10;
