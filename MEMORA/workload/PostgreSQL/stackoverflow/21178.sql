
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM U.CreationDate) ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.PostTypeId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        (SELECT COUNT(*) 
         FROM Votes V2 
         WHERE V2.PostId = P.Id AND V2.VoteTypeId IN (1, 7)) AS AcceptedVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.OwnerUserId, P.Title, P.CreationDate, P.PostTypeId
),
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.CommentCount,
        RP.UpVotes,
        RP.DownVotes,
        RP.AcceptedVotes,
        U.DisplayName AS OwnerName,
        COALESCE(RU.UserRank, 9999) AS CreatorRank 
    FROM 
        RecentPosts RP
    LEFT JOIN 
        Users U ON RP.OwnerUserId = U.Id
    LEFT JOIN 
        RankedUsers RU ON U.Id = RU.UserId
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.CommentCount,
    PD.UpVotes,
    PD.DownVotes,
    PD.AcceptedVotes,
    PD.OwnerName,
    CASE 
        WHEN PD.CommentCount > 10 THEN 'Highly Engaged'
        WHEN PD.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    CASE 
        WHEN PD.CreatorRank IS NULL THEN 'N/A'
        ELSE CONCAT('Post rank: ', PD.CreatorRank)
    END AS RankStatus
FROM 
    PostDetails PD
WHERE 
    PD.CommentCount > 0 OR PD.UpVotes > 0
ORDER BY 
    PD.UpVotes DESC, 
    PD.CommentCount DESC,
    PD.CreationDate DESC
LIMIT 100;
