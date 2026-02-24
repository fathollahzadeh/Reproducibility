
WITH TagStatistics AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COALESCE(AVG(U.Reputation), 0) AS AvgUserReputation,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS ActiveUsers
    FROM 
        Tags T
        LEFT JOIN Posts P ON P.Tags LIKE '%' || '<' || T.TagName || '>'
        LEFT JOIN Votes V ON V.PostId = P.Id AND V.VoteTypeId IN (9, 8) 
        LEFT JOIN Users U ON U.Id = P.OwnerUserId
    GROUP BY 
        T.Id, T.TagName
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        T.TagName,
        P.CreationDate,
        P.Score,
        RANK() OVER (PARTITION BY T.Id ORDER BY P.Score DESC) AS PopularityRank
    FROM 
        Posts P 
        JOIN Tags T ON P.Tags LIKE '%' || '<' || T.TagName || '>'
    WHERE 
        P.PostTypeId = 1 
),
RecentEdits AS (
    SELECT 
        PH.PostId,
        STRING_AGG(DISTINCT PH.UserDisplayName || ' (' || PH.CreationDate || ')', '; ') AS EditsDetails
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.PostId
)
SELECT 
    TS.TagId,
    TS.TagName,
    TS.PostCount,
    TS.TotalBounty,
    TS.AvgUserReputation,
    TS.ActiveUsers,
    AP.PostId,
    AP.Title,
    AP.CreationDate,
    AP.Score,
    AP.PopularityRank,
    RE.EditsDetails
FROM 
    TagStatistics TS
    LEFT JOIN ActivePosts AP ON TS.TagName = AP.TagName
    LEFT JOIN RecentEdits RE ON AP.PostId = RE.PostId
WHERE 
    TS.PostCount > 0
ORDER BY 
    TS.TagName, 
    AP.Score DESC, 
    RE.EditsDetails;
