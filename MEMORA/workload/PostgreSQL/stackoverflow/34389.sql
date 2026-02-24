WITH RecursiveTopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        U.DisplayName AS OwnerName,
        COALESCE(COUNT(A.Id), 0) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Posts A ON A.ParentId = P.Id
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, U.DisplayName
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        P.Title,
        MAX(PH.CreationDate) AS LastEditedDate,
        COUNT(PH.Id) AS EditCount,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS Editors
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        Users U ON PH.UserId = U.Id
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.PostId, PH.UserId, P.Title
),
PostWithBadges AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        B.Name AS BadgeName,
        B.Class,
        B.Date AS BadgeDate,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Posts P
    LEFT JOIN 
        Badges B ON B.UserId = P.OwnerUserId
)
SELECT 
    R.PostId,
    R.Title,
    R.Score,
    R.CreationDate,
    R.OwnerName,
    R.AnswerCount,
    PH.LastEditedDate,
    PH.EditCount,
    PH.Editors,
    PB.BadgeName,
    PB.Class,
    PB.BadgeRank
FROM 
    RecursiveTopPosts R
LEFT JOIN 
    PostHistorySummary PH ON R.PostId = PH.PostId
LEFT JOIN 
    PostWithBadges PB ON R.PostId = PB.PostId AND PB.BadgeRank = 1
WHERE 
    (R.Rank <= 10 OR PH.EditCount > 0) 
ORDER BY 
    R.Score DESC, PH.LastEditedDate DESC;