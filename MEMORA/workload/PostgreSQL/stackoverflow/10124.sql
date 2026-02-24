
WITH PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS ClosureCount,
        SUM(CASE WHEN B.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.LastActivityDate
)
SELECT 
    P.Title,
    P.CreationDate,
    P.LastActivityDate,
    P.CommentCount,
    P.VoteCount,
    P.ClosureCount,
    P.BadgeCount,
    EXTRACT(EPOCH FROM (P.LastActivityDate - P.CreationDate)) AS ActiveDuration
FROM 
    PostActivity P
ORDER BY 
    P.VoteCount DESC, P.LastActivityDate DESC;
