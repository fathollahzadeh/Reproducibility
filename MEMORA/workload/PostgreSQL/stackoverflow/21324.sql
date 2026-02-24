
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN v.Id ELSE 0 END), 0) AS TotalDownVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),

QuestionStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseActions,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeletionActions,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(DISTINCT ph.UserId) AS UsersWhoClosed
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.OwnerUserId
),

AggregatedStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.TotalUpVotes,
        ups.TotalDownVotes,
        ups.GoldBadges,
        ups.SilverBadges,
        ups.BronzeBadges,
        qs.CloseActions,
        qs.DeletionActions,
        qs.LastClosedDate,
        qs.UsersWhoClosed
    FROM 
        UserPostStats ups
    LEFT JOIN 
        QuestionStats qs ON ups.UserId = qs.OwnerUserId
)

SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalUpVotes,
    TotalDownVotes,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    COALESCE(CloseActions, 0) AS CloseActions,
    COALESCE(DeletionActions, 0) AS DeletionActions,
    CASE 
        WHEN LastClosedDate IS NOT NULL THEN 'Closed on ' || CAST(LastClosedDate AS VARCHAR)
        ELSE 'Never Closed'
    END AS CloseStatus,
    UsersWhoClosed
FROM 
    AggregatedStats
WHERE 
    TotalPosts > 0
ORDER BY 
    TotalUpVotes DESC, TotalQuestions DESC
LIMIT 10;
