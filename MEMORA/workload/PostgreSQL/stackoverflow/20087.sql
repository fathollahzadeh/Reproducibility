WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        MAX(P.CreationDate) AS LastActivity,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostLinks PL ON P.Id = PL.PostId
    GROUP BY 
        P.Id, P.OwnerUserId, P.Score
),
UserEngagement AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        SUM(COALESCE(PA.CommentCount, 0)) AS TotalCommentsMade,
        SUM(COALESCE(PA.RelatedPostCount, 0)) AS TotalRelatedPostsEngaged
    FROM 
        UserStats US
    LEFT JOIN 
        PostAnalytics PA ON US.UserId = PA.OwnerUserId
    GROUP BY 
        US.UserId, US.DisplayName, US.Reputation
),
Feedback AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        (U.UpVotes - U.DownVotes) AS NetVotes,
        ROW_NUMBER() OVER (PARTITION BY U.UserId ORDER BY U.Reputation DESC) AS VoteRank
    FROM 
        UserStats U
)
SELECT 
    UE.Reputation,
    UE.DisplayName,
    UE.TotalCommentsMade,
    UE.TotalRelatedPostsEngaged,
    F.NetVotes,
    F.VoteRank,
    CASE 
        WHEN UE.Reputation IS NULL THEN 'Unknown User'
        WHEN UE.Reputation < 100 THEN 'Newbie'
        WHEN UE.Reputation BETWEEN 100 AND 1000 THEN 'Contributor'
        ELSE 'Expert'
    END AS ReputationGroup,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Badges B WHERE B.UserId = UE.UserId AND B.Class = 1) THEN 'Gold Member'
        ELSE 'Normal Member'
    END AS MembershipStatus
FROM 
    UserEngagement UE
LEFT JOIN 
    Feedback F ON UE.UserId = F.UserId
WHERE 
    UE.TotalCommentsMade > 5
ORDER BY 
    UE.TotalCommentsMade DESC, UE.Reputation DESC;
