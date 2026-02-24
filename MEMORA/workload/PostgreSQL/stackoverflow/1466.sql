
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(NULLIF(P.AcceptedAnswerId, -1), 0) AS AcceptedAnswerId,
        COALESCE(V.UpVotes, 0) AS TotalUpVotes,
        COALESCE(V.DownVotes, 0) AS TotalDownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserRank,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    WHERE P.PostTypeId = 1 
),
UserBadges AS (
    SELECT 
        UserId, 
        COUNT(*) FILTER (WHERE Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE Class = 3) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
ClosedPosts AS (
    SELECT 
        PH.PostId, 
        MIN(PH.CreationDate) AS FirstClosedDate,
        COUNT(*) AS CloseChangeCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    CP.FirstClosedDate,
    CP.CloseChangeCount,
    RP.TotalUpVotes,
    RP.TotalDownVotes,
    CASE 
        WHEN CP.CloseChangeCount > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS IsClosed,
    CASE 
        WHEN RP.UserRank = 1 THEN 'Most Recent'
        ELSE 'Other'
    END AS PostRank
FROM 
    RankedPosts RP
LEFT JOIN UserBadges UB ON RP.OwnerUserId = UB.UserId
LEFT JOIN ClosedPosts CP ON RP.PostId = CP.PostId
WHERE 
    RP.TotalUpVotes > 10 OR 
    RP.UserRank = 1
ORDER BY 
    RP.CreationDate DESC, 
    RP.TotalUpVotes DESC;
