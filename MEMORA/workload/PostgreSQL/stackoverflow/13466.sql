WITH PostStats AS (
    SELECT
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS UniquePostOwners,
        SUM(COALESCE(ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(Score, 0)) AS TotalScore
    FROM
        Posts
),
UserStats AS (
    SELECT
        COUNT(*) AS TotalUsers,
        SUM(Reputation) AS TotalReputation
    FROM
        Users
),
VoteStats AS (
    SELECT
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM
        Votes
),
BadgeStats AS (
    SELECT
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS TotalGoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS TotalSilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS TotalBronzeBadges
    FROM
        Badges
),
RecentPost AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS Author,
        P.CreationDate
    FROM
        Posts P
    JOIN
        Users U ON P.OwnerUserId = U.Id
    ORDER BY
        P.CreationDate DESC
    LIMIT 1
)

SELECT
    PS.TotalPosts,
    PS.UniquePostOwners,
    PS.TotalViews,
    PS.TotalScore,
    US.TotalUsers,
    US.TotalReputation,
    VS.TotalVotes,
    VS.TotalUpVotes,
    VS.TotalDownVotes,
    BS.TotalBadges,
    BS.TotalGoldBadges,
    BS.TotalSilverBadges,
    BS.TotalBronzeBadges,
    RP.PostId,
    RP.Title AS RecentPostTitle,
    RP.Author AS RecentAuthor,
    RP.CreationDate AS RecentPostDate
FROM
    PostStats PS,
    UserStats US,
    VoteStats VS,
    BadgeStats BS,
    RecentPost RP;