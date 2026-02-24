
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.LastActivityDate,
        COALESCE(PH.UserDisplayName, 'Anonymous') AS LastEditedBy,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.CreationDate = (
            SELECT MAX(CreationDate) 
            FROM PostHistory 
            WHERE PostId = P.Id
        )
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT 
        U.Id as UserId,
        U.DisplayName,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U 
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    WHERE 
        B.Class = 1 
    GROUP BY 
        B.UserId
),
UserRanking AS (
    SELECT 
        UE.UserId,
        UE.DisplayName,
        UE.VoteCount,
        UE.UpVotes,
        UE.DownVotes,
        COALESCE(TB.BadgeCount, 0) AS GoldBadges,
        RANK() OVER (ORDER BY UE.VoteCount DESC) AS EngagementRank
    FROM 
        UserEngagement UE
    LEFT JOIN 
        TopBadges TB ON UE.UserId = TB.UserId
),
FinalReport AS (
    SELECT 
        RP.Title,
        RP.PostId,
        RP.Score,
        RP.LastEditedBy,
        UR.DisplayName AS EngagingUser,
        UR.VoteCount,
        UR.UpVotes,
        UR.DownVotes,
        UR.GoldBadges,
        RP.ScoreRank
    FROM 
        RankedPosts RP
    LEFT JOIN 
        UserRanking UR ON UR.UserId IN (
            SELECT UserId FROM Votes WHERE PostId = RP.PostId
        )
    WHERE 
        RP.ScoreRank <= 10
    ORDER BY 
        RP.Score DESC
)

SELECT 
    FR.*,
    CASE 
        WHEN FR.GoldBadges > 0 THEN 'Gold Badge Holder'
        ELSE 'Regular User'
    END AS UserStatus,
    CASE 
        WHEN FR.Score IS NULL THEN 'No Score'
        ELSE 'Score Available'
    END AS ScoreStatus
FROM 
    FinalReport FR
WHERE 
    FR.EngagingUser IS NOT NULL
ORDER BY 
    FR.Score DESC, FR.EngagingUser;
