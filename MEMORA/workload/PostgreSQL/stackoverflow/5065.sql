
WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS TotalComments,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS TotalUpVotes,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY P.CreationDate DESC) AS RowNum
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
),
PostStatistics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.CreationDate,
        RP.OwnerDisplayName,
        RP.TotalComments,
        RP.TotalUpVotes,
        RP.TotalDownVotes,
        (RP.TotalUpVotes - RP.TotalDownVotes) AS NetVotes,
        CASE 
            WHEN RP.TotalComments > 5 THEN 'Hot'
            WHEN RP.TotalUpVotes > 10 THEN 'Trending'
            ELSE 'New'
        END AS PostCategory,
        ROW_NUMBER() OVER (ORDER BY RP.CreationDate DESC) AS RowNum
    FROM 
        RecentPosts RP
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.Body,
    PS.CreationDate,
    PS.OwnerDisplayName,
    PS.TotalComments,
    PS.TotalUpVotes,
    PS.TotalDownVotes,
    PS.NetVotes,
    PS.PostCategory,
    PH.UserDisplayName AS LastEditor,
    PH.CreationDate AS LastEditDate,
    PHT.Name AS PostHistoryTypeName
FROM 
    PostStatistics PS
LEFT JOIN 
    PostHistory PH ON PS.PostId = PH.PostId
LEFT JOIN 
    PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
WHERE 
    PS.RowNum <= 50
ORDER BY 
    PS.CreationDate DESC;
