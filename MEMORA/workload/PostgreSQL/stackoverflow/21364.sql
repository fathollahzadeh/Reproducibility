
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title AS PostTitle,
        P.Body,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND P.Score IS NOT NULL 
        AND P.PostTypeId IN (1, 2)  
),
PostVoteDetails AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId IN (10, 11) THEN 1 END) AS Deletions,
        COUNT(CASE WHEN V.VoteTypeId IN (4, 12) THEN 1 END) AS OffensiveReports
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 12) THEN 1 END) AS Changes,
        STRING_AGG(PH.Comment, '; ') AS Comments
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId, 
    RP.PostTitle,
    RP.OwnerDisplayName,
    RP.CreationDate,
    COALESCE(PVD.UpVotes, 0) AS TotalUpVotes,
    COALESCE(PVD.DownVotes, 0) AS TotalDownVotes,
    COALESCE(PVD.Deletions, 0) AS TotalDeletions,
    COALESCE(PVD.OffensiveReports, 0) AS TotalOffensiveReports,
    COALESCE(PHD.Changes, 0) AS TotalChanges,
    COALESCE(PHD.Comments, 'No comments') AS RecentComments
FROM 
    RankedPosts RP
LEFT JOIN 
    PostVoteDetails PVD ON RP.PostId = PVD.PostId
LEFT JOIN 
    PostHistoryDetails PHD ON RP.PostId = PHD.PostId
WHERE 
    RP.Rank <= 5 
    AND (COALESCE(PVD.UpVotes, 0) - COALESCE(PVD.DownVotes, 0) > 0 OR RP.PostTitle LIKE '%interesting%')
ORDER BY 
    RP.Rank, RP.CreationDate DESC;
