
WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.Score,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostsRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
), 
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
), 
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        U.DisplayName AS Owner,
        US.UpVotes,
        US.DownVotes,
        U.Reputation,
        RP.CreationDate
    FROM 
        RecentPosts RP
    JOIN 
        Users U ON RP.OwnerUserId = U.Id
    JOIN 
        UserStats US ON U.Id = US.UserId
    WHERE 
        RP.UserPostsRank <= 5
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.Owner,
    PD.UpVotes,
    PD.DownVotes,
    PD.CreationDate,
    CASE 
        WHEN PD.UpVotes > PD.DownVotes THEN 'Positive Engagement'
        WHEN PD.UpVotes < PD.DownVotes THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementLevel,
    EXISTS (
        SELECT 1 
        FROM Posts P 
        WHERE P.AcceptedAnswerId = PD.PostId
    ) AS HasAcceptedAnswer
FROM 
    PostDetails PD
ORDER BY 
    PD.CreationDate DESC;
