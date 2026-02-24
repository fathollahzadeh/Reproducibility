WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
        AND P.Score > 0
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostVoteHistory AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId = 6 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN V.VoteTypeId = 7 THEN 1 END) AS ReopenVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    RB.BadgeCount,
    RB.BadgeNames,
    RP.PostId,
    RP.Title AS QuestionTitle,
    RP.CreationDate AS QuestionDate,
    PH.PostHistoryTypeId,
    PH.CreationDate AS HistoryDate,
    COALESCE(PVH.UpVotes, 0) AS UpVotes,
    COALESCE(PVH.DownVotes, 0) AS DownVotes,
    COALESCE(PVH.CloseVotes, 0) AS CloseVotes,
    COALESCE(PVH.ReopenVotes, 0) AS ReopenVotes,
    PH.Comment
FROM 
    RankedPosts RP
JOIN 
    Users U ON RP.PostRank = 1 AND RP.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.Id)
LEFT JOIN 
    UserBadges RB ON U.Id = RB.UserId
LEFT JOIN 
    PostHistory PH ON RP.PostId = PH.PostId
LEFT JOIN 
    PostVoteHistory PVH ON RP.PostId = PVH.PostId
WHERE 
    PH.CreationDate < RP.CreationDate 
    AND PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
ORDER BY 
    U.Reputation DESC, 
    RP.Score DESC 
LIMIT 100;