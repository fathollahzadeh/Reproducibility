WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS Owner,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY COUNT(V.Id) DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id, U.DisplayName
),
TopActions AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS ActionCount
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
),
PostStatistics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        COALESCE(SUM(CASE WHEN TA.PostHistoryTypeId IN (10, 11) THEN TA.ActionCount END), 0) AS CloseActions,
        COALESCE(SUM(CASE WHEN TA.PostHistoryTypeId = 24 THEN TA.ActionCount END), 0) AS EditSuggestions,
        RP.UpVotes - RP.DownVotes AS NetVotes
    FROM 
        RankedPosts RP
    LEFT JOIN 
        TopActions TA ON RP.PostId = TA.PostId
    GROUP BY 
        RP.PostId, RP.Title, RP.CreationDate, RP.UpVotes, RP.DownVotes
)
SELECT 
    PS.Title,
    PS.CreationDate,
    PS.NetVotes,
    PS.CloseActions,
    PS.EditSuggestions,
    (SELECT 
        STRING_AGG(B.Name, ', ') 
     FROM 
        Badges B 
     WHERE 
        B.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = PS.PostId)) AS UserBadges
FROM 
    PostStatistics PS
WHERE 
    PS.NetVotes > 0
    AND PS.CloseActions = 0
ORDER BY 
    PS.NetVotes DESC
LIMIT 10;