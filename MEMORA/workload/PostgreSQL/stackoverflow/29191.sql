
WITH TaggedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        TS.TagName
    FROM 
        Posts P
    CROSS JOIN 
        UNNEST(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')) AS TS(TagName)
    WHERE 
        P.PostTypeId = 1 
), 
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
    HAVING 
        U.Reputation > 1000 
),
ActivitySummary AS (
    SELECT 
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVoteCount,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.OwnerUserId
)

SELECT 
    TP.PostId,
    TP.Title,
    TP.Body,
    TP.CreationDate,
    TP.ViewCount,
    TP.TagName,
    UR.DisplayName AS Author,
    UR.Reputation,
    UR.BadgeCount,
    ASU.CommentCount,
    ASU.UpVoteCount,
    ASU.DownVoteCount
FROM 
    TaggedPosts TP
INNER JOIN 
    UserReputation UR ON TP.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = UR.UserId)
LEFT JOIN 
    ActivitySummary ASU ON UR.UserId = ASU.OwnerUserId
ORDER BY 
    TP.ViewCount DESC, 
    UR.Reputation DESC
LIMIT 50;
