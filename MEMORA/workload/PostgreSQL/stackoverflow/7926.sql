WITH VotesSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(HS.TotalVotes, 0) AS TotalVotes,
        COALESCE(HS.UpVotes, 0) AS UpVotes,
        COALESCE(HS.DownVotes, 0) AS DownVotes,
        U.DisplayName AS Author,
        P.CreationDate AS PostDate
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        VotesSummary HS ON P.Id = HS.PostId
    WHERE 
        P.PostTypeId = 1 
),
RankedPosts AS (
    SELECT 
        PD.*,
        RANK() OVER (ORDER BY PD.Score DESC, PD.TotalVotes DESC, PD.ViewCount DESC) AS Rank
    FROM 
        PostDetails PD
)
SELECT 
    RP.Rank,
    RP.Title,
    RP.Author,
    RP.Score,
    RP.ViewCount,
    RP.UpVotes,
    RP.DownVotes,
    RP.PostDate
FROM 
    RankedPosts RP
WHERE 
    RP.Rank <= 10
ORDER BY 
    RP.Rank;