WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(b.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
VoteCounts AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT v.PostId) AS VotedPosts
    FROM Votes v
    GROUP BY v.UserId
)

SELECT 
    u.Id, 
    u.DisplayName,
    COALESCE(ubs.GoldBadges, 0) AS GoldBadges,
    COALESCE(ubs.SilverBadges, 0) AS SilverBadges,
    COALESCE(ubs.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.QuestionCount, 0) AS QuestionCount,
    COALESCE(ps.AnswerCount, 0) AS AnswerCount,
    COALESCE(ps.TotalScore, 0) AS TotalScore,
    COALESCE(vcs.UpVotes, 0) AS UpVotes,
    COALESCE(vcs.DownVotes, 0) AS DownVotes,
    COALESCE(vcs.VotedPosts, 0) AS VotedPosts,
    CASE 
        WHEN COALESCE(ubs.TotalBadges, 0) > 0 THEN 'Active User'
        WHEN COALESCE(ps.TotalPosts, 0) = 0 AND COALESCE(vcs.VotedPosts, 0) = 0 THEN 'Inactive User'
        ELSE 'Moderate User'
    END AS UserStatus,
    LEAD(u.CreationDate) OVER (ORDER BY u.CreationDate) AS NextUserCreationDate,
    ROW_NUMBER() OVER (ORDER BY COALESCE(ps.TotalScore, 0) DESC, u.Reputation DESC) AS Rank
FROM Users u
LEFT JOIN UserBadgeStats ubs ON u.Id = ubs.UserId
LEFT JOIN PostSummary ps ON u.Id = ps.OwnerUserId
LEFT JOIN VoteCounts vcs ON u.Id = vcs.UserId
WHERE u.Reputation > 1000 AND (COALESCE(ubs.TotalBadges, 0) > 2 OR COALESCE(ps.TotalPosts, 0) > 5)
ORDER BY Rank, u.DisplayName
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;

