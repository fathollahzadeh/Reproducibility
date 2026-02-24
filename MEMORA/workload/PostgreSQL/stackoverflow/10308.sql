WITH PostVoteCounts AS (
    SELECT 
        P.PostTypeId,
        COUNT(V.Id) AS VoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.PostTypeId
),
PostTypeDetails AS (
    SELECT 
        PT.Name AS PostTypeName,
        PVC.VoteCount,
        PVC.UpVoteCount,
        PVC.DownVoteCount
    FROM 
        PostTypes PT
    JOIN 
        PostVoteCounts PVC ON PT.Id = PVC.PostTypeId
)
SELECT 
    PTD.PostTypeName,
    PTD.VoteCount,
    PTD.UpVoteCount,
    PTD.DownVoteCount
FROM 
    PostTypeDetails PTD
ORDER BY 
    PTD.VoteCount DESC;