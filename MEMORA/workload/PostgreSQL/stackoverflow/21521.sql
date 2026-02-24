
WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM
        Users U
    WHERE
        U.Reputation > (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL)
),
RecentPosts AS (
    SELECT
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        P.Title,
        P.CreationDate,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    WHERE
        P.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY
        P.Id, P.OwnerUserId, P.PostTypeId, P.Title, P.CreationDate, P.AcceptedAnswerId, P.Score
),
HistoricChanges AS (
    SELECT
        PH.PostId,
        MAX(PH.CreationDate) AS LastChangeDate,
        STRING_AGG(PHT.Name, ', ') AS ChangeTypes
    FROM
        PostHistory PH
    JOIN
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY
        PH.PostId
),
TopPosts AS (
    SELECT
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.CommentCount,
        CASE 
            WHEN RP.PostTypeId = 1 THEN 'Question'
            WHEN RP.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType,
        U.DisplayName AS OwnerDisplayName,
        R.Reputation
    FROM
        RecentPosts RP
    JOIN
        Users U ON RP.OwnerUserId = U.Id
    JOIN
        UserReputation R ON U.Id = R.UserId
    WHERE
        RP.CommentCount > 5
    ORDER BY
        RP.Score DESC
    LIMIT 10
)
SELECT
    TP.Title,
    TP.OwnerDisplayName,
    TP.PostType,
    TP.Score,
    H.LastChangeDate,
    H.ChangeTypes,
    COALESCE(Tags.TagName, 'No Tags') AS Tags
FROM
    TopPosts TP
LEFT JOIN
    (SELECT 
        P.Id, 
        STRING_AGG(T.TagName, ', ') AS TagName
     FROM 
        Posts P
     LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(P.Tags, ',')) AS tag_array ON tag_array IS NOT NULL
     LEFT JOIN 
        Tags T ON T.TagName = TRIM(tag_array)
     GROUP BY 
        P.Id) Tags ON TP.PostId = Tags.Id
JOIN
    HistoricChanges H ON TP.PostId = H.PostId
WHERE
    TP.Score < (SELECT AVG(Score) FROM RecentPosts)
ORDER BY
    TP.Score DESC,
    H.LastChangeDate DESC;
