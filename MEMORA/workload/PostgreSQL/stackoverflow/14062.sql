WITH PostMetrics AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS UniquePostOwners,
        AVG(ViewCount) AS AvgViewCount,
        SUM(CASE WHEN AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Posts
),
UserMetrics AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AvgReputation,
        COUNT(DISTINCT CASE WHEN LastAccessDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN Id END) AS ActiveUsersLast30Days
    FROM 
        Users
),
VoteMetrics AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Votes
),
BadgeMetrics AS (
    SELECT 
        COUNT(*) AS TotalBadges,
        COUNT(DISTINCT UserId) AS UsersWithBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
),
PostHistoryMetrics AS (
    SELECT 
        COUNT(*) AS TotalPostHistories,
        COUNT(DISTINCT PostId) AS UniquePostsEdited,
        COUNT(DISTINCT UserId) AS UniqueEditors
    FROM 
        PostHistory
)

SELECT 
    pm.TotalPosts,
    pm.UniquePostOwners,
    pm.AvgViewCount,
    pm.TotalAcceptedAnswers,
    pm.TotalQuestions,
    pm.TotalAnswers,
    um.TotalUsers,
    um.AvgReputation,
    um.ActiveUsersLast30Days,
    vm.TotalVotes,
    vm.TotalUpVotes,
    vm.TotalDownVotes,
    bm.TotalBadges,
    bm.UsersWithBadges,
    bm.GoldBadges,
    bm.SilverBadges,
    bm.BronzeBadges,
    phm.TotalPostHistories,
    phm.UniquePostsEdited,
    phm.UniqueEditors
FROM 
    PostMetrics pm,
    UserMetrics um,
    VoteMetrics vm,
    BadgeMetrics bm,
    PostHistoryMetrics phm;