
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        p.Tags,
        p.Score,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM
        Posts p
    JOIN Users U ON p.OwnerUserId = U.Id
    WHERE
        p.PostTypeId = 1 
),
PostHistoryStats AS (
    SELECT
        ph.PostId,
        COUNT(DISTINCT ph.UserId) AS EditorCount,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
),
UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM
        Users U
    LEFT JOIN Badges b ON U.Id = b.UserId
    GROUP BY
        U.Id, U.DisplayName, U.Reputation
)
SELECT
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.OwnerDisplayName,
    RP.Tags,
    RP.Score,
    PH.EditorCount,
    PH.EditCount,
    PH.LastEditDate,
    UR.DisplayName AS UserReputationName,
    UR.Reputation,
    UR.BadgeCount,
    RP.TagRank
FROM
    RankedPosts RP
LEFT JOIN PostHistoryStats PH ON RP.PostId = PH.PostId
JOIN UserReputation UR ON RP.OwnerUserId = UR.UserId
WHERE
    RP.TagRank <= 3 
ORDER BY
    RP.Tags, RP.TagRank;
