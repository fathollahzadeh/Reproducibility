WITH RECURSIVE UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
), RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Score,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COALESCE((SELECT MAX(B.Date) FROM Badges B WHERE B.UserId = P.OwnerUserId AND B.Class = 1), '1900-01-01') AS LastGoldBadgeDate
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.OwnerUserId, P.Score, P.Title, P.CreationDate
), PostAnalytics AS (
    SELECT 
        U.DisplayName,
        UPC.PostCount,
        RP.Title,
        RP.Score,
        RP.UpVotes,
        RP.DownVotes,
        RP.CommentCount,
        RP.LastGoldBadgeDate,
        CASE 
            WHEN RP.UpVotes > RP.DownVotes THEN 'Positively Reviewed'
            WHEN RP.UpVotes < RP.DownVotes THEN 'Negatively Reviewed'
            ELSE 'Neutral'
        END AS ReviewStatus
    FROM 
        RankedPosts RP
    JOIN 
        UserPostCounts UPC ON RP.OwnerUserId = UPC.UserId
    JOIN 
        Users U ON RP.OwnerUserId = U.Id
    WHERE 
        RP.rn = 1 AND 
        RP.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
)
SELECT 
    P.*,
    CASE 
        WHEN P.CommentCount > 0 THEN 'Commented'
        ELSE 'No Comments'
    END AS CommentStatus,
    CASE 
        WHEN P.LastGoldBadgeDate >= cast('2024-10-01' as date) - INTERVAL '3 years' THEN 'Active Contributor'
        ELSE 'Occasional Contributor'
    END AS ContributorType
FROM 
    PostAnalytics P
ORDER BY 
    P.Score DESC, 
    P.PostCount DESC;