
WITH UserParticipation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopContributors AS (
    SELECT 
        UserId,
        DisplayName,
        PostsCreated,
        UpVotesReceived,
        DownVotesReceived,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY PostsCreated DESC) AS PostRank,
        RANK() OVER (ORDER BY UpVotesReceived DESC) AS UpVoteRank,
        RANK() OVER (ORDER BY DownVotesReceived DESC) AS DownVoteRank
    FROM 
        UserParticipation
),
FinalRanking AS (
    SELECT 
        UserId,
        DisplayName,
        PostsCreated,
        UpVotesReceived,
        DownVotesReceived,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        PostRank,
        UpVoteRank,
        DownVoteRank,
        ROW_NUMBER() OVER (ORDER BY PostsCreated DESC, UpVotesReceived DESC) AS FinalRank
    FROM 
        TopContributors
)
SELECT 
    UserId,
    DisplayName,
    PostsCreated,
    UpVotesReceived,
    DownVotesReceived,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    FinalRank
FROM 
    FinalRanking
WHERE 
    FinalRank <= 20
ORDER BY 
    FinalRank;
